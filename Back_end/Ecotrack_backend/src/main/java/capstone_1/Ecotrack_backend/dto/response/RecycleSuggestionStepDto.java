package capstone_1.Ecotrack_backend.dto.response;

public class RecycleSuggestionStepDto {

    private Integer stepOrder;
    private String stepTitle;
    private String stepDescription;
    private String instructionImageUrl;
    private String instructionVideoUrl;

    public Integer getStepOrder() {
        return stepOrder;
    }

    public void setStepOrder(Integer stepOrder) {
        this.stepOrder = stepOrder;
    }

    public String getStepTitle() {
        return stepTitle;
    }

    public void setStepTitle(String stepTitle) {
        this.stepTitle = stepTitle;
    }

    public String getStepDescription() {
        return stepDescription;
    }

    public void setStepDescription(String stepDescription) {
        this.stepDescription = stepDescription;
    }

    public String getInstructionImageUrl() {
        return instructionImageUrl;
    }

    public void setInstructionImageUrl(String instructionImageUrl) {
        this.instructionImageUrl = instructionImageUrl;
    }

    public String getInstructionVideoUrl() {
        return instructionVideoUrl;
    }

    public void setInstructionVideoUrl(String instructionVideoUrl) {
        this.instructionVideoUrl = instructionVideoUrl;
    }
}
